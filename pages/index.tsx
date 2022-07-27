import type { NextPage } from 'next';
import dynamic from "next/dynamic";
import Head from 'next/head';
import GameContainer from '../components/GameContainer';
import { GameProvider } from "../components/GameProvider";




const GameCanvas = dynamic(() => import("../components/GameCanvas"), {
    ssr: false,
});


const Home: NextPage = () => {

    return (
        <div>
            <Head>
                <title>DogCat</title>
                <meta name="description" content="Basically two-ended snake" />
                <link rel="icon" href="/favicon.ico" />
            </Head>
            <GameProvider rows={25} columns={25}>
                <GameContainer>
                    <GameCanvas width={800} height={800} />
                </GameContainer>
            </GameProvider>
        </div>
    )
}

export default Home
